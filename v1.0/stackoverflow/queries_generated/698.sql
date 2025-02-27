WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(v.Score) AS AvgVoteScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(trim(both '{}' from Tags), ',')) AS TagName,
        COUNT(*) AS TagFrequency
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 8 THEN ph.CreationDate END) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    um.DisplayName,
    um.Reputation,
    um.TotalPosts,
    um.Questions,
    um.Answers,
    um.AcceptedAnswers,
    um.AvgVoteScore,
    ts.TagName,
    ts.TagFrequency,
    phd.EditCount,
    phd.LastEditDate
FROM 
    UserMetrics um
CROSS JOIN 
    TagStatistics ts
LEFT JOIN 
    PostHistoryDetails phd ON um.UserId = phd.PostId
WHERE 
    um.Reputation >= 100
AND 
    (um.Question > 20 OR um.AcceptedAnswers > 5)
ORDER BY 
    um.Reputation DESC, 
    ts.TagFrequency DESC
LIMIT 50;
