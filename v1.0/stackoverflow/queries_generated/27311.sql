WITH PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        u.DisplayName AS Author,
        u.Reputation,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
),
Benchmarking AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        pd.EditCount,
        pd.CommentCount,
        pd.TagList,
        CASE
            WHEN pd.ViewCount > 1000 THEN 'High Traffic'
            WHEN pd.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate Traffic'
            ELSE 'Low Traffic'
        END AS TrafficCategory,
        EXTRACT(EPOCH FROM pd.LastActivityDate - pd.CreationDate) AS TimeToFirstComment,  -- seconds
        EXTRACT(DAY FROM pd.LastActivityDate - pd.CreationDate) AS DaysActive
    FROM 
        PostDetail pd
)
SELECT 
    bc.TrafficCategory,
    COUNT(bc.PostId) AS PostCount,
    AVG(bc.ViewCount) AS AvgViews,
    AVG(bc.EditCount) AS AvgEdits,
    AVG(bc.CommentCount) AS AvgComments,
    AVG(bc.TimeToFirstComment) AS AvgTimeToFirstComment,
    AVG(bc.DaysActive) AS AvgDaysActive
FROM 
    Benchmarking bc
GROUP BY 
    bc.TrafficCategory
ORDER BY 
    FIELD(bc.TrafficCategory, 'High Traffic', 'Moderate Traffic', 'Low Traffic');
