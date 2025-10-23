"use client";

import { useState, useEffect } from 'react';
import { Globe, Zap, ShieldCheck, Cpu, Server, BarChart3, X } from 'lucide-react';

type ConfirmationModalProps = {
  onConfirm: () => void;
  onCancel: () => void;
};

const ConfirmationModal = ({ onConfirm, onCancel }: ConfirmationModalProps) => {
  return (
    <div className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50 p-4">
      <div className="bg-gray-800 rounded-lg p-8 max-w-sm w-full text-center relative shadow-xl">
        <button onClick={onCancel} className="absolute top-4 right-4 text-gray-400 hover:text-white">
          <X size={24} />
        </button>
        <ShieldCheck className="h-16 w-16 mx-auto mb-4 text-red-500" />
        <h3 className="text-2xl font-bold mb-4">Security Test</h3>
        <p className="text-gray-300 mb-6">
          You are about to send a request that mimics a common web attack.
          Our WAF will block it, and you should see a **&quot;403 Forbidden&quot;** page. This is the expected result.
        </p>
        <div className="flex justify-center gap-4">
          <button onClick={onCancel} className="bg-gray-600 hover:bg-gray-500 text-white font-bold py-2 px-6 rounded-full">
            Cancel
          </button>
          <button onClick={onConfirm} className="bg-red-600 hover:bg-red-500 text-white font-bold py-2 px-6 rounded-full">
            Proceed
          </button>
        </div>
      </div>
    </div>
  );
};

export default function Home() {
  const [location, setLocation] = useState('...');
  const [edgeLocation, setEdgeLocation] = useState('...');
  const [threats, setThreats] = useState(0);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleTestSecurity = () => {
    const maliciousUrl = window.location.origin + '?q=<script>alert("xss")</script>';
    window.location.href = maliciousUrl;
  };

  useEffect(() => {
    if (window.location.hostname !== 'localhost') {

    // --- single, reliable API endpoint ---
    const baseApiUrl = '/default/getVisitorLocation';
    const cacheBuster = `?cacheBust=${new Date().getTime()}`;

    // --- Fetch Location Data ---
    fetch(`${baseApiUrl}?action=location&${cacheBuster.substring(1)}`)
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json();
      })
      .then(data => {
        // --- FIX: Changed data.country to data.region ---
        // The API returns 'city' and 'region', not 'country'.
        setLocation(`${data.city || 'N/A'}, ${data.region || 'N/A'}`);
        setEdgeLocation(data.edgeLocation || 'N/A');
      })
      .catch(error => {
        console.error("Error fetching location data:", error);
        setLocation("Error");
        setEdgeLocation("Error");
      });

    // --- Fetch WAF Block Count ---
    fetch(`${baseApiUrl}?action=waf&${cacheBuster.substring(1)}`)
      .then(response => {
         if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json();
      })
      .then(data => {
        setThreats(data.blockCount || 0);
      })
      .catch(error => {
        console.error("Error fetching WAF data:", error);
        setThreats(0);
      });
    } else {
      setLocation('Localhost');
      setEdgeLocation('N/A');
      setThreats(0);
      
    }

  }, []);

  return (
    <div className="bg-gray-900 text-white min-h-screen font-sans">
      {/* Conditionally render the modal */}
      {isModalOpen && <ConfirmationModal onConfirm={handleTestSecurity} onCancel={() => setIsModalOpen(false)} />}
      
      <main className="container mx-auto px-4 py-8 md:py-16">
        <section className="text-center mb-20 md:mb-32">
          <h1 className="text-5xl md:text-7xl font-bold mb-4 bg-clip-text text-transparent bg-gradient-to-r from-purple-400 to-cyan-400">
            Aether Drone
          </h1>
          <p className="text-lg md:text-xl text-gray-300 max-w-3xl mx-auto mb-8">
            Capture your world from a new perspective. Unmatched stability, 4K clarity, and intelligent flight modes in a stunningly compact design.
          </p>
          <div className="flex flex-col sm:flex-row justify-center gap-4 mb-12">
            <a href="#features" className="bg-purple-600 hover:bg-purple-700 text-white font-bold py-3 px-8 rounded-full transition-transform transform hover:scale-105">
              Learn More
            </a>
            <a href="#insights" className="bg-gray-700 hover:bg-gray-600 text-white font-bold py-3 px-8 rounded-full transition-transform transform hover:scale-105">
              Live Insights
            </a>
          </div>
          <div className="w-full max-w-4xl mx-auto bg-gray-800 rounded-lg shadow-2xl overflow-hidden">
             <img 
                src="https://placehold.co/1200x600/1f2937/38bdf8?text=Aether+Drone+Image" 
                alt="Aether Drone in a futuristic studio setting" 
                className="w-full h-auto object-cover"
                onError={(e) => {
                  const target = e.target as HTMLImageElement;
                  target.onerror = null; 
                  target.src='https://placehold.co/1200x600/1f2937/38bdf8?text=Aether+Drone';
                }}
             />
          </div>
        </section>

        {/* --- Features Section --- */}
        <section id="features" className="mb-20 md:mb-32">
          <h2 className="text-4xl font-bold text-center mb-12">Why Aether is Different</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
            <div className="bg-gray-800 p-8 rounded-lg">
              <Globe className="h-12 w-12 mx-auto mb-4 text-purple-400" />
              <h3 className="text-2xl font-semibold mb-2">Global Reach</h3>
              <p className="text-gray-400">Deployed on a global CDN for instant access, anywhere in the world.</p>
            </div>
            <div className="bg-gray-800 p-8 rounded-lg">
              <Zap className="h-12 w-12 mx-auto mb-4 text-purple-400" />
              <h3 className="text-2xl font-semibold mb-2">Blazing Fast</h3>
              <p className="text-gray-400">A serverless architecture means sub-second load times and zero lag.</p>
            </div>
            <div className="bg-gray-800 p-8 rounded-lg">
              <ShieldCheck className="h-12 w-12 mx-auto mb-4 text-purple-400" />
              <h3 className="text-2xl font-semibold mb-2">Ironclad Security</h3>
              <p className="text-gray-400">Protected by a Web Application Firewall against modern threats.</p>
            </div>
          </div>
        </section>

        {/* --- Live Technical Insights Section --- */}
        <section id="insights" className="bg-gray-800 p-6 md:p-8 rounded-lg shadow-xl">
          <h2 className="text-4xl font-bold text-center mb-4">Live Technical Insights</h2>
          <p className="text-center text-gray-400 mb-12">
            This website is self-aware. The data below is generated in real-time to demonstrate the power of our cloud architecture.
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="bg-gray-900 p-6 rounded-lg text-center min-w-0">
              <Cpu className="h-10 w-10 mx-auto mb-3 text-cyan-400" />
              <h3 className="text-lg font-semibold text-gray-400 mb-2">Your Location</h3>
              <p className="text-2xl font-bold text-white truncate">{location}</p>
            </div>
            <div className="bg-gray-900 p-6 rounded-lg text-center min-w-0">
              <Server className="h-10 w-10 mx-auto mb-3 text-cyan-400" />
              <h3 className="text-lg font-semibold text-gray-400 mb-2">Serving Edge Location</h3>
              <p className="text-2xl font-bold text-white truncate">{edgeLocation}</p>
            </div>
            <div className="bg-gray-900 p-6 rounded-lg text-center min-w-0">
              <BarChart3 className="h-10 w-10 mx-auto mb-3 text-cyan-400" />
              <h3 className="text-lg font-semibold text-gray-400 mb-2">Threats Blocked (Last Hour)</h3>
              <p className="text-2xl font-bold text-white">{threats}</p>
            </div>
          </div>
           <div className="text-center mt-8">
              <button 
                onClick={() => setIsModalOpen(true)}
                className="bg-red-600 hover:bg-red-700 text-white font-bold py-2 px-6 rounded-full transition-transform transform hover:scale-105"
              >
                Test Security
              </button>
            </div>
        </section>

      </main>

      {/* --- Footer --- */}
      <footer className="text-center py-8 border-t border-gray-700">
        <p className="text-gray-500">&copy; {new Date().getFullYear()} Aether Dynamics. All rights reserved.</p>
      </footer>
    </div>
  );
}


