import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Brain, Cpu, Rocket } from 'lucide-react'
import { Link } from "react-router-dom"

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-900 to-gray-800 text-white">
      <header className="container mx-auto px-4 py-6 flex justify-between items-center">
        <div className="flex items-center space-x-2">
          <Brain className="w-8 h-8" />
          <span className="text-2xl font-bold">AIAgentLaunch</span>
        </div>
        <nav>
          <ul className="flex space-x-4">
            <li><a href="#features" className="hover:text-blue-400">Features</a></li>
            <li><a href="#about" className="hover:text-blue-400">About</a></li>
            <li><a href="#contact" className="hover:text-blue-400">Contact</a></li>
          </ul>
        </nav>
      </header>

      <main className="container mx-auto px-4 py-12">
        <section className="text-center mb-16">
          <h1 className="text-5xl font-bold mb-4">Create AI Agents & Launch Tokens in a Single Prompt</h1>
          <p className="text-xl mb-8">Revolutionize your blockchain projects with our all-in-one AI agent and ICO platform</p>
          <Link to="/launch">
            <Button size="lg" className="bg-blue-600 hover:bg-blue-700">
              Launch App
            </Button>
          </Link>
        </section>
        <section id="features" className="mb-16">
          <h2 className="text-3xl font-bold mb-8 text-center">Features</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <FeatureCard
              icon={<Brain className="w-12 h-12 mb-4 text-blue-400" />}
              title="AI Agent Creation"
              description="Create sophisticated AI agents with a single prompt, powered by advanced machine learning algorithms."
            />
            <FeatureCard
              icon={<Rocket className="w-12 h-12 mb-4 text-blue-400" />}
              title="Token Launch"
              description="Seamlessly launch your own tokens on the SUI blockchain with our intuitive ICO platform."
            />
            <FeatureCard
              icon={<Cpu className="w-12 h-12 mb-4 text-blue-400" />}
              title="Virtual Environments"
              description="Deploy your AI agents in customizable virtual environments, similar to virtuals.io."
            />
          </div>
        </section>

        <section id="about" className="mb-16 text-center">
          <h2 className="text-3xl font-bold mb-4">About Us</h2>
          <p className="text-xl">
            We're passionate about combining AI and blockchain technology to create innovative solutions. 
            Our platform empowers developers and entrepreneurs to bring their ideas to life quickly and efficiently.
          </p>
        </section>

        <section id="contact" className="text-center">
          <h2 className="text-3xl font-bold mb-4">Contact Us</h2>
          <p className="text-xl mb-4">Have questions? Reach out to us!</p>
          <Button variant="outline">Send a Message</Button>
        </section>
      </main>

      <footer className="bg-gray-900 py-6 text-center">
        <p>&copy; 2025 AIAgentLaunch. All rights reserved.</p>
      </footer>

    </div>
  )
}

interface FeatureCardProps {
  icon: React.ReactNode;
  title: string;
  description: string;
}

function FeatureCard({ icon, title, description }: FeatureCardProps) {
  return (
    <Card className="bg-gray-800 border-gray-700">
      <CardContent className="text-center p-6">
        {icon}
        <h3 className="text-xl font-semibold mb-2">{title}</h3>
        <p>{description}</p>
      </CardContent>
    </Card>
  )
}