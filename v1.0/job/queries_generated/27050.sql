WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT m.id) > 1
),
selected_titles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ROW_NUMBER() OVER (PARTITION BY rt.production_year ORDER BY rt.company_count DESC) AS title_rank
    FROM 
        ranked_titles rt
)
SELECT 
    st.title,
    st.production_year,
    ak.name AS cast_name,
    p.info AS person_info,
    ct.kind AS company_type,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords
FROM 
    selected_titles st
JOIN 
    complete_cast cc ON st.title_id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id
LEFT JOIN 
    movie_companies mc ON st.title_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON st.title_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    st.title_rank <= 5
GROUP BY 
    st.title, st.production_year, ak.name, p.info, ct.kind
ORDER BY 
    st.production_year DESC, title;
