WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id
),
TopTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        company_count
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    tt.title_id,
    tt.title,
    tt.production_year,
    tt.company_count,
    cd.actor_count,
    cd.actor_names
FROM 
    TopTitles tt
LEFT JOIN 
    CastDetails cd ON tt.title_id = cd.movie_id
ORDER BY 
    tt.production_year DESC, tt.company_count DESC;
