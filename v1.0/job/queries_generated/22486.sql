WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) as title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) as titles_count
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Movie%')
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) as movie_count
    FROM 
        cast_info c
    JOIN 
        RankedTitles rt ON c.movie_id = rt.id
    GROUP BY 
        c.person_id
),
PersonWithMaxMovies AS (
    SELECT 
        person_id,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) as rank
    FROM 
        ActorMovieCounts
),
MoviesWithCast AS (
    SELECT 
        m.title,
        m.production_year,
        p.name,
        pm.gender,
        p.person_id
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name p ON c.person_id = p.person_id
    LEFT JOIN 
        person_info pm ON c.person_id = pm.person_id
    WHERE 
        pm.info_type_id = (SELECT id FROM info_type WHERE info = 'gender')
),
FilteredMovies AS (
    SELECT 
        mwc.title,
        mwc.production_year,
        mwc.name
    FROM 
        MoviesWithCast mwc
    WHERE 
        mwc.gender IS NOT NULL
),
FinalOutput AS (
    SELECT 
        f.title,
        f.production_year,
        f.name,
        (SELECT COUNT(DISTINCT company_name.id) 
         FROM movie_companies mc 
         JOIN company_name ON mc.company_id = company_name.id 
         WHERE mc.movie_id = f.movie_id AND company_name.country_code IS NOT NULL) AS companies_count
    FROM 
        FilteredMovies f
    WHERE 
        EXISTS (SELECT 1 
                FROM PersonWithMaxMovies pm 
                WHERE pm.person_id = f.person_id 
                AND pm.rank <= 5)
)
SELECT 
    title,
    production_year,
    name,
    companies_count,
    CASE 
        WHEN companies_count IS NULL THEN 'No Companies'
        WHEN companies_count > 5 THEN 'Too Many Companies'
        ELSE 'Normal' 
    END AS company_count_category
FROM 
    FinalOutput
ORDER BY 
    production_year DESC, 
    title;
