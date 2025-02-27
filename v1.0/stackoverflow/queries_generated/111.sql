WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvotesReceived,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostMetrics AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        u.Reputation,
        u.UpvotesReceived,
        u.DownvotesReceived,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer,
        CASE 
            WHEN COALESCE(SUM(c.Id),0) > 0 THEN 1 
            ELSE 0 
        END AS HasComments
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.Reputation
),
FinalOutput AS (
    SELECT 
        rp.Title,
        rp.Score,
        rp.ViewCount,
        ur.Reputation,
        pm.HasAcceptedAnswer,
        pm.HasComments,
        CASE 
            WHEN rp.Rank <= 5 THEN 'Top 5'
            ELSE 'Other'
        END AS RankCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    JOIN 
        PostMetrics pm ON rp.Id = pm.Id
)

SELECT 
    RankCategory,
    COUNT(*) AS PostCount,
    AVG(Score) AS AvgScore,
    SUM(ViewCount) AS TotalViews,
    AVG(Reputation) AS AvgReputation,
    SUM(CASE WHEN HasAcceptedAnswer = 1 THEN 1 ELSE 0 END) AS AcceptedAnswers,
    SUM(CASE WHEN HasComments = 1 THEN 1 ELSE 0 END) AS PostsWithComments
FROM 
    FinalOutput
GROUP BY 
    RankCategory
HAVING 
    AVG(Score) > 5
ORDER BY 
    RankCategory;
