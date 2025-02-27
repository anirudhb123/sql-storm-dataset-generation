WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id 
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE((SELECT SUM(Score) FROM Comments c WHERE c.PostId = p.Id), 0) AS TotalCommentScore,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) AS AgeInSeconds,
        CASE 
            WHEN p.Score IS NULL THEN 'No Score'
            WHEN p.Score > 0 THEN 'Positive'
            ELSE 'Negative'
        END AS ScoreCategory
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '6 months'
),
TagMetrics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        AVG(COALESCE(pm.Score, 0)) AS AvgPostScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]) AND p.PostTypeId = 1
    LEFT JOIN 
        PostMetrics pm ON p.Id = pm.PostId
    GROUP BY 
        t.TagName
),
ClosedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS CloseCount,
        MAX(CASE WHEN PH.CreationDate > p.CreationDate THEN PH.CreationDate END) AS LastCloseDate
    FROM 
        PostHistory PH 
    INNER JOIN 
        Posts p ON PH.PostId = p.Id 
    WHERE 
        PH.PostHistoryTypeId = 10 /* Close action */
    GROUP BY 
        PostId
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.PostCount,
    ur.TotalBounty,
    tm.TagName,
    tm.QuestionCount,
    tm.TotalAnswers,
    tm.AvgPostScore,
    cp.CloseCount,
    cp.LastCloseDate,
    pm.Score AS LatestPostScore,
    pm.ScoreCategory,
    CASE 
        WHEN cp.CloseCount IS NULL THEN 'Open'
        ELSE 'Closed'
    END AS PostStatus
FROM 
    UserReputation ur
LEFT JOIN 
    PostMetrics pm ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = (SELECT MIN(PostId) FROM ClosedPosts)) /* Assume latest post by user */
LEFT JOIN 
    TagMetrics tm ON pm.PostId = (SELECT MIN(PostId) FROM ClosedPosts) /* Assuming leading post tagged */
LEFT JOIN 
    ClosedPosts cp ON pm.PostId = cp.PostId
WHERE 
    ur.Rank <= 50
ORDER BY 
    ur.Reputation DESC, 
    tm.QuestionCount DESC, 
    cp.LastCloseDate ASC NULLS LAST;
