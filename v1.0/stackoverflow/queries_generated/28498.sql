WITH TagCounts AS (
    SELECT 
        tag.TagName, 
        COUNT(p.Id) AS PostCount,
        ARRAY_AGG(DISTINCT u.DisplayName ORDER BY u.Reputation DESC) AS TopUsers,
        SUM(COALESCE(b.Reputation, 0)) AS TotalUserReputation
    FROM 
        Tags tag
    LEFT JOIN 
        Posts p ON p.Tags ILIKE '%' || tag.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        tag.TagName
),
PostAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(v.CreationDate), CURRENT_TIMESTAMP) AS LastVoteDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, pt.Name
),
BenchmarkingResults AS (
    SELECT 
        tc.TagName,
        tc.PostCount,
        tc.TopUsers,
        tc.TotalUserReputation,
        pa.Title,
        pa.CommentCount,
        pa.LastVoteDate,
        pa.LastEditDate,
        pa.CloseCount
    FROM 
        TagCounts tc
    JOIN 
        PostAnalysis pa ON pa.PostId IN (
            SELECT 
                p.Id 
            FROM 
                Posts p 
            WHERE 
                p.Tags ILIKE '%' || tc.TagName || '%'
            LIMIT 5
        )
    ORDER BY 
        tc.PostCount DESC
)
SELECT 
    *,
    CASE 
        WHEN CommentCount > 20 THEN 'Highly Engaging'
        WHEN CommentCount BETWEEN 10 AND 20 THEN 'Moderately Engaging'
        ELSE 'Less Engaging'
    END AS EngagementLevel
FROM 
    BenchmarkingResults
ORDER BY 
    TotalUserReputation DESC, PostCount DESC;
