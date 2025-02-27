WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
MovieData AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        c.name AS company_name,
        a.name AS actor_name
    FROM 
        RankedTitles rt
    JOIN 
        title m ON rt.title_id = m.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = m.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        rt.rank <= 5
),
AggregatedData AS (
    SELECT 
        production_year,
        COUNT(DISTINCT title) AS title_count,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors
    FROM 
        MovieData
    GROUP BY 
        production_year
)
SELECT 
    production_year,
    title_count,
    keywords,
    companies,
    actors
FROM 
    AggregatedData
ORDER BY 
    production_year DESC;
