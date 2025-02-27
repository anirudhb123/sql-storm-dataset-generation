WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) as rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopActors AS (
    SELECT 
        ak.name, 
        ak.person_id, 
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name, ak.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) >= 5
),
MovieCompanies AS (
    SELECT 
        m.movie_id, 
        c.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
FinalResults AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        ta.name AS top_actor, 
        mc.company_name, 
        mc.company_type 
    FROM 
        RankedMovies rm
    LEFT JOIN 
        TopActors ta ON rm.movie_id = (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = ta.person_id LIMIT 1)
    LEFT JOIN 
        MovieCompanies mc ON rm.movie_id = mc.movie_id
    WHERE 
        rm.rank <= 10
)
SELECT 
    movie_id, 
    title, 
    production_year, 
    top_actor, 
    company_name, 
    company_type 
FROM 
    FinalResults
ORDER BY 
    production_year DESC, 
    movie_id;
