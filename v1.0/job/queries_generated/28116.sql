WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.kind AS company_type,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        aka_name ak ON at.id = ak.id
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
PersonDetails AS (
    SELECT 
        n.name AS person_name,
        p.info AS person_info,
        string_agg(DISTINCT c.nr_order::text || ': ' || r.role, ', ') AS roles
    FROM 
        name n
    JOIN 
        cast_info c ON n.id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        person_info p ON n.id = p.person_id
    GROUP BY 
        n.id, n.name, p.info
),
FinalBenchmark AS (
    SELECT 
        m.movie_title,
        m.production_year,
        m.movie_keyword,
        m.company_type,
        m.aka_names,
        p.person_name,
        p.person_info,
        p.roles
    FROM 
        MovieDetails m
    JOIN 
        PersonDetails p ON m.movie_title LIKE '%' || p.person_name || '%'
    ORDER BY 
        m.production_year DESC, m.movie_title
)
SELECT 
    *
FROM 
    FinalBenchmark
WHERE 
    movie_keyword ILIKE '%action%' AND company_type = 'Producer'
LIMIT 100;
