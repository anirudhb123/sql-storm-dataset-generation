WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        tk.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY tk.keyword) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword tk ON mk.keyword_id = tk.id
    WHERE 
        t.production_year >= 2000
),
aggregated_names AS (
    SELECT 
        ak.person_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_name ak
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.person_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        ri.role AS role_name,
        COALESCE(ak.aka_names, 'No Alternate Names') AS alternate_names
    FROM 
        cast_info ci
    JOIN 
        role_type ri ON ci.role_id = ri.id
    LEFT JOIN 
        aggregated_names ak ON ci.person_id = ak.person_id
),
movie_overview AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names,
        STRING_AGG(DISTINCT cd.role_name || ' (' || cd.alternate_names || ')', '; ') AS cast_roles
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        cast_details cd ON m.id = cd.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, ct.kind
)
SELECT 
    mo.title,
    mo.production_year,
    mo.company_names,
    mo.cast_roles,
    rt.keyword AS significant_keyword
FROM 
    movie_overview mo
JOIN 
    ranked_titles rt ON mo.movie_id = rt.title_id
WHERE 
    rt.rank <= 3
ORDER BY 
    mo.production_year DESC, mo.title;
