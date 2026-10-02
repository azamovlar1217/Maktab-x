import type { Metadata } from "next";
import { OnboardingTour } from "@/components/onboarding-tour";

export const metadata:Metadata={title:"MAKTAB X bilan tanishing",description:"Bilim, darslar va yutuqlar bo‘ylab qisqa tanishuv."};
export default function WelcomePage(){return <OnboardingTour/>}
