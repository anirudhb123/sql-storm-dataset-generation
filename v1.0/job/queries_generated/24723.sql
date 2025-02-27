WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(kw.keyword, 'No Keywords') AS keyword,
        m.production_year
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
),
DeceasedCastMembers AS (
    SELECT
        p.person_id,
        p.name,
        pi.info,
        ROW_NUMBER() OVER (PARTITION BY p.person_id ORDER BY pi.info_type_id) AS row_num
    FROM 
        name p
    JOIN 
        person_info pi ON p.id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Death')
),
FrequentActors AS (
    SELECT 
        ci.person_id,
        COUNT(*) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(*) > 5
)
SELECT 
    m.title AS Movie_Title,
    m.production_year AS Year,
    ak.name AS Actor_Name,
    COALESCE(k.keyword, 'N/A') AS Keyword,
    CASE 
        WHEN dac.row_num IS NOT NULL THEN 'Deceased'
        ELSE 'Alive'
    END AS Actor_Status
FROM 
    MoviesWithKeywords m
JOIN 
    cast_info c ON m.movie_id = c.movie_id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    DeceasedCastMembers dac ON ak.person_id = dac.person_id
LEFT JOIN 
    FrequentActors fa ON ak.person_id = fa.person_id
WHERE 
    m.actor_rank <= 3
AND 
    m.production_year BETWEEN 2000 AND 2010
ORDER BY 
    m.production_year DESC, m.title;
