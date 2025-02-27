WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY k.id ORDER BY t.production_year DESC) AS rnk
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000 -- Considering titles produced after 2000
),
RecentAkaNames AS (
    SELECT 
        an.id AS aka_id,
        an.name,
        an.person_id
    FROM 
        aka_name an
    JOIN 
        RankedTitles rt ON rt.title_id = an.person_id -- Assuming person_id relates to titles
    WHERE 
        an.name IS NOT NULL AND LENGTH(an.name) > 5 -- Filtering out names that are too short
),
CastDetails AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        p.gender,
        r.role,
        COUNT(*) OVER (PARTITION BY ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        person_info pi ON ci.person_id = pi.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        name p ON pi.person_id = p.imdb_id -- Assuming imdb_id in name corresponds to person_id
    WHERE 
        r.role LIKE '%Lead%' -- Filtering to include only lead roles
),
TopActors AS (
    SELECT 
        cd.person_id,
        cd.gender,
        COUNT(DISTINCT cd.movie_id) AS movie_count
    FROM 
        CastDetails cd
    GROUP BY 
        cd.person_id, cd.gender
    HAVING 
        COUNT(DISTINCT cd.movie_id) > 2 -- Considering actors with more than 2 movies
)
SELECT 
    rt.title,
    rt.production_year,
    an.name AS actor_name,
    ta.gender,
    ta.movie_count
FROM 
    RankedTitles rt
JOIN 
    RecentAkaNames an ON an.aka_id = rt.title_id 
JOIN 
    TopActors ta ON ta.person_id = an.person_id
WHERE 
    rt.rnk = 1 -- Selecting only the most recent title for each keyword
ORDER BY 
    rt.production_year DESC, 
    ta.movie_count DESC;
