WITH RankedMovies AS (
    SELECT 
        t.id as movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) as title_rank,
        COUNT(*) OVER() as total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) as movies_starred,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) as note_null_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
MovieDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        COALESCE(SUM(mk.keyword_id), 0) as keyword_count,
        MAX(CASE WHEN wi.id IS NOT NULL THEN 1 ELSE 0 END) as has_winning_actor
    FROM 
        RankedMovies r
    LEFT JOIN 
        movie_keyword mk ON r.movie_id = mk.movie_id
    LEFT JOIN 
        (SELECT DISTINCT 
            ci.movie_id, 
            ci.person_id 
        FROM 
            cast_info ci 
        JOIN 
            person_info pi ON ci.person_id = pi.person_id 
        WHERE 
            pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Oscar Winner')) wi ON r.movie_id = wi.movie_id
    GROUP BY 
        r.movie_id, r.title, r.production_year
),
CompanyData AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mci.id) as info_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN
        movie_info mci ON mc.movie_id = mci.movie_id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    md.title AS movie_title,
    md.production_year,
    md.keyword_count,
    ca.name AS actor_name,
    ca.movies_starred,
    ca.note_null_count,
    cd.company_name,
    cd.company_type,
    cd.info_count,
    md.has_winning_actor
FROM 
    MovieDetails md
JOIN 
    FilteredActors ca ON EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = md.movie_id 
        AND ci.person_id = ca.person_id
    )
LEFT JOIN 
    CompanyData cd ON md.movie_id = cd.movie_id
WHERE 
    md.production_year IS NOT NULL
    AND (md.has_winning_actor = 1 OR md.keyword_count > 0)
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC, 
    ca.movies_starred DESC
LIMIT 50 OFFSET 10;
