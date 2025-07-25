"use client";

import { useState, useEffect } from 'react';
import { Globe, Zap, ShieldCheck, Cpu, Server, BarChart3 } from 'lucide-react';

export default function Home() {
  const [location, setLocation] = useState('...');
  const [edgeLocation, setEdgeLocation] = useState('...');
  const [threats, setThreats] = useState('...');

  useEffect(() => {
    const apiUrl = 'https://u1v9pb60g4.execute-api.us-east-2.amazonaws.com/default/getVisitorLocation'; 

    // This check prevents the app from crashing if the URL isn't set.
    if (apiUrl.includes('PASTE_YOUR_API_ENDPOINT_URL_HERE') || !apiUrl) {
      console.error("API URL is not configured. Please paste your API Gateway endpoint URL in the 'apiUrl' variable.");
      setLocation('API Not Configured');
      setEdgeLocation('API Not Configured');
      return; // Stop the function here
    }
    
    fetch(apiUrl)
      .then(response => response.json())
      .then(data => {
        setLocation(`${data.city || 'N/A'}, ${data.country || 'N/A'}`);
        setEdgeLocation(data.edgeLocation || 'N/A');
      })
      .catch(error => {
        console.error("Error fetching location data:", error);
        setLocation('Unavailable');
        setEdgeLocation('Unavailable');
      });
  }, []);

  return (
    <div className="bg-gray-900 text-white min-h-screen font-sans">
      <main className="container mx-auto px-4 py-8 md:py-16">

        {/* --- Hero Section --- */}
        <section className="text-center mb-20 md:mb-32">
          <h1 className="text-5xl md:text-7xl font-bold mb-4 bg-clip-text text-transparent bg-gradient-to-r from-purple-400 to-cyan-400">
            Aether Drone
          </h1>
          <p className="text-lg md:text-xl text-gray-300 max-w-3xl mx-auto mb-8">
            Capture your world from a new perspective. Unmatched stability, 4K clarity, and intelligent flight modes in a stunningly compact design.
          </p>
          <div className="flex justify-center gap-4 mb-12">
            <a href="#features" className="bg-purple-600 hover:bg-purple-700 text-white font-bold py-3 px-8 rounded-full transition-transform transform hover:scale-105">
              Learn More
            </a>
            <a href="#insights" className="bg-gray-700 hover:bg-gray-600 text-white font-bold py-3 px-8 rounded-full transition-transform transform hover:scale-105">
              Live Insights
            </a>
          </div>
          <div className="w-full max-w-4xl mx-auto bg-gray-800 rounded-lg shadow-2xl overflow-hidden">
             <img 
                src="/aether_drone.png" 
                alt="Aether Drone in a futuristic studio setting" 
                className="w-full h-auto object-cover"
             />
          </div>
        </section>

        {/* --- Features Section --- */}
        <section id="features" className="mb-20 md:mb-32">
          <h2 className="text-4xl font-bold text-center mb-12">Why Aether is Different</h2>
          <div className="grid md:grid-cols-3 gap-8 text-center">
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
        <section id="insights" className="bg-gray-800 p-8 rounded-lg shadow-xl">
          <h2 className="text-4xl font-bold text-center mb-4">Live Technical Insights</h2>
          <p className="text-center text-gray-400 mb-12">
            This website is self-aware. The data below is generated in real-time to demonstrate the power of our cloud architecture.
          </p>
          <div className="grid md:grid-cols-3 gap-8">
            <div className="bg-gray-900 p-6 rounded-lg text-center">
              <Cpu className="h-10 w-10 mx-auto mb-3 text-cyan-400" />
              <h3 className="text-lg font-semibold text-gray-400 mb-2">Your Location</h3>
              <p className="text-2xl font-bold text-white">{location}</p>
            </div>
            <div className="bg-gray-900 p-6 rounded-lg text-center">
              <Server className="h-10 w-10 mx-auto mb-3 text-cyan-400" />
              <h3 className="text-lg font-semibold text-gray-400 mb-2">Serving Edge Location</h3>
              <p className="text-2xl font-bold text-white">{edgeLocation}</p>
            </div>
            <div className="bg-gray-900 p-6 rounded-lg text-center">
              <BarChart3 className="h-10 w-10 mx-auto mb-3 text-cyan-400" />
              <h3 className="text-lg font-semibold text-gray-400 mb-2">Threats Blocked (Last Hour)</h3>
              <p className="text-2xl font-bold text-white">{threats}</p>
            </div>
          </div>
           <div className="text-center mt-8">
              <button className="bg-red-600 hover:bg-red-700 text-white font-bold py-2 px-6 rounded-full transition-transform transform hover:scale-105 disabled:opacity-50" disabled>
                Test Security (Coming Soon)
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
