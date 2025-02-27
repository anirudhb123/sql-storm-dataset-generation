WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year, 
        t.kind_id, 
        RANK() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieDetails AS (
    SELECT 
        mt.movie_id,
        mt.company_id,
        mt.company_type_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_companies mt
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.movie_id, mt.company_id, mt.company_type_id
), 
PersonRoles AS (
    SELECT 
        c.person_id,
        c.movie_id,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id, c.movie_id
)
SELECT 
    a.name AS actor_name,
    rt.title,
    rt.production_year,
    pt.roles,
    md.keyword_count,
    COALESCE(md.keywords, 'No Keywords') AS keywords,
    ct.kind AS company_type
FROM 
    aka_name a
JOIN 
    PersonRoles pt ON a.person_id = pt.person_id
JOIN 
    RankedTitles rt ON pt.movie_id IN (
        SELECT movie_id 
        FROM RankedTitles 
        WHERE rank <= 5
    )
JOIN 
    movie_companies mc ON pt.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    MovieDetails md ON pt.movie_id = md.movie_id
WHERE 
    (md.keyword_count > 0 OR md.keyword_count IS NULL)
    AND rt.production_year > 2000
ORDER BY 
    rt.production_year DESC, a.name;
