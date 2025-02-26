 NYC 311 Request Insights 2024: A Data Dashboard Challenge

Authors
- Yared Asefa  
- Mohamed M  
- Sakaria Dirie  

---

Challenge Overview

Succinct Statement of the Data Challenge
The challenge is to develop an interactive dashboard that analyzes NYC 311 service requests in 2024. Using a curated subset of fields from the comprehensive 311 dataset, the dashboard will reveal patterns and insights on:

- The most common types of complaints overall, by borough, and by month.
- The typical response time by comparing the request creation and closure dates.
- The agency that received the highest volume of complaints.
- The most frequent channels through which 311 requests are submitted.
- The most common times of day when requests are made.

Purpose & Intent
This dashboard's objective is to use historical and real-time data visualizations to give a wide range of stakeholders relevant insights. By showing patterns and trends in service requests, decision-makers may improve response processes, more efficiently allocate resources, and identify problem areas. The dashboard makes an effort to combine exploratory data analysis with narrative-driven insights to offer both an overview and the choice to go further into specifics.

Stakeholders
- City Officiala & Government Agencies: Need real-time insights for decision-making, resource allocation, and policy adjustments.
- Community Boards & Local Leaders: Require neighborhood-level data to address recurring issues and advocate for community improvements.
- The General Public: Residents can stay informed about the frequency and nature of service requests, fostering transparency and community engagement.

Key Analytical Questions
The visual analytics techniques implemented in this dashboard should address the following questions:

 Complaint Trends:
- What are the most common types of complaints in NYC in 2024?
- How do these complaint types vary across boroughs and change month by month?

 Response Times:
- How long does it usually take for a request to be closed or looked at?
- Are there variations in response times based on complaint type, borough, or the agency involved?

 Agency Involvement:
- Which agency receives the most 311 requests and what types of complaints do they handle most frequently?

 Communication Channels:
- What is the most common method by which residents submit their 311 requests?

 Temporal Patterns:
- When are most service requests submitted throughout the day?

By answering these questions, the dashboard helps uncover service bottlenecks and inefficiencies while equipping stakeholders with the insights they need to take targeted action. With this data, they can implement strategic improvements to streamline operations and enhance overall efficiency.

---

 Proposed Project Plan

The project will span 4 weeks with the following phases and tasks:

 Week 1: Data Exploration & Design Ideation
- Data Import:
  - Import the 311 dataset and filter for 2024.
  - Clean the data by addressing missing values and ensuring correct formats (e.g., parsing dates for created_date and closed_date).
- Initial Sketch:
  - Brainstorm and sketch initial dashboard layouts.
  - Define key metrics and determine which visualizations best address our analytical questions.
- First Meeting:
  - Discuss roles, responsibilities, and set communication channels among team members.

 Week 2: Prototype Development
- Visualization Prototyping:
  - Create initial ggplot prototypes for:
    - Complaint type bar charts.
    - Monthly trend line charts.
    - Time-of-day histogram.
  - Start processing calculations for response times (difference between created_date and closed_date).
- Iterative Feedback:
  - Present prototypes in team meetings.
  - Refine visualizations based on feedback.

 Week 3: Dashboard Build & Integration
- Dashboard Development:
  - Integrate the refined visualizations into an interactive dashboard framework.
  - Develop interactive filtering and drill-down capabilities.
- User Interface & Aesthetics:
  - Focus on the overall layout, color schemes, and responsiveness of the dashboard.
  - Incorporate the sidebar with filtering options and a dynamic header.

 Week 4: Testing, Feedback, and Deployment
- User Testing & Feedback Collection:
  - Share the dashboard with a small group of target users (stakeholders, peers) to collect feedback on usability and insights.
  - Identify and fix any bugs or usability issues.
- Final Adjustments & Deployment:
  - Finalize the dashboard design, ensuring all visualizations and interactive elements work as intended.
  - Deploy the dashboard on a hosting platform and ensure the live data connection is functioning.
- Documentation & Final Presentation:
  - Document the design process, coding decisions, and any challenges faced.
  - Prepare a final presentation outlining the project’s insights and outcomes.

 Possible Team Roles
- Project Manager: Oversees the timeline and coordinates group meetings.
- Data Analyst/Engineer: Handles data cleaning, transformation, and calculations.
- Visualization Specialist: Develops the static and interactive visualizations.

---

 Background

 Data Biography
The dataset used for this challenge is the "311 Service Requests from 2010 to Present" dataset provided by NYC OpenData. Updated daily, this comprehensive dataset includes over 39 million rows, each representing a unique service request (filtered here to focus on 2024). For this analysis, we are concentrating on a subset of fields critical for understanding and mapping car-related issues and broader service request trends:

- Address Type, City, Landmark: Categorizes the location and context of the service request.
- Status & Due Date: Provides insights into the progress and timeliness of service resolution.
- Borough & Incident Zip: Essential for geographic visualization and borough-level comparisons.
- Open Data Channel Type: Indicates how requests are submitted, which helps in understanding citizen engagement.
- Vehicle Type & Agency: Offers details on the nature of the complaint and the responsible agency.
- Complaint Type & Descriptor: Forms the basis for analyzing the nature of the issues reported.
- Unique Key, Created Date, Closed Date, Resolution Description: Serve as identifiers and time stamps to calculate response times and track the lifecycle of each request.

The dataset is invaluable for public sector analysis as it provides real-time insights into community needs and government responsiveness. It supports evidence-based decision-making for improving service delivery and urban management in NYC.

---

 References

- 311 (2025) 311 service requests from 2010 to present: NYC Open Data. Available at: [NYC Open Data](https://data.cityofnewyork.us/Social-Services/311-Service-Requests-from-2010-to-Present/erm2-nwe9) (Accessed: 13 February 2025).  
- Andrews, C. (2024) From calls to insights: Analyzing 311 service requests in Calgary. Available at: [Medium](https://medium.com/@carolyn.A13/from-calls-to-insights-analyzing-311-service-requests-in-calgary-bc24d917d5c9) (Accessed: 13 February 2025).

