
WITH RankedTitles AS (
    SELECT 
        a.id AS aka_title_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY RANDOM()) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
HighlightedNames AS (
    SELECT 
        n.id AS name_id,
        n.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        name n
    JOIN 
        cast_info c ON n.id = c.person_id
    WHERE 
        n.gender = 'F' 
    GROUP BY 
        n.id, n.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
PopularCompanies AS (
    SELECT 
        co.name AS company_name,
        COUNT(mc.movie_id) AS total_movies
    FROM 
        company_name co
    JOIN 
        movie_companies mc ON co.id = mc.company_id
    GROUP BY 
        co.name
    ORDER BY 
        total_movies DESC
    LIMIT 10
),
ExtendedCast AS (
    SELECT 
        ci.movie_id,
        n.name AS actor_name,
        r.role AS actor_role,
        a.title AS movie_title,
        a.production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name n ON ci.person_id = n.person_id
    JOIN 
        aka_title a ON ci.movie_id = a.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
)
SELECT 
    ht.title AS highlighted_title,
    ht.production_year,
    hn.name AS top_female_actor,
    pc.company_name,
    ec.actor_name,
    ec.actor_role
FROM 
    RankedTitles ht
JOIN 
    HighlightedNames hn ON hn.movie_count > 5 
JOIN 
    PopularCompanies pc ON pc.total_movies > 10
JOIN 
    ExtendedCast ec ON ec.movie_id = ht.aka_title_id
WHERE 
    ht.rank <= 3
ORDER BY 
    ht.production_year DESC, 
    pc.total_movies DESC;
