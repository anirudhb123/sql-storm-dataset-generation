WITH RecursivePostCounts AS (
    -- CTE to get the post count for each user recursively based on their posts and related posts
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId

    UNION ALL

    SELECT 
        pl.PostId,
        COUNT(*) + rp.PostCount
    FROM 
        PostLinks pl
    JOIN 
        RecursivePostCounts rp ON pl.RelatedPostId = rp.OwnerUserId
    GROUP BY 
        pl.PostId
),

UserReputationRank AS (
    -- Aggregate user reputations and rank them
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),

TaggedPosts AS (
    -- Get posts with a specific tag
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS t(TagName) ON t.TagName IS NOT NULL
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Body
)

SELECT 
    u.DisplayName,
    u.Reputation,
    ur.ReputationRank,
    COALESCE(rp.PostCount, 0) AS TotalPosts,
    tp.PostId,
    tp.Title,
    tp.Tags,
    tp.Body,
    CASE 
        WHEN tp.Body IS NULL THEN 'No content available'
        ELSE LEFT(tp.Body, 100) || '...' -- Truncate body for display
    END AS DisplayBody
FROM 
    Users u
LEFT JOIN 
    UserReputationRank ur ON u.Id = ur.UserId
LEFT JOIN 
    RecursivePostCounts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    TaggedPosts tp ON tp.PostId IN (SELECT PostId FROM PostLinks WHERE LinkTypeId = 1) -- Linked posts
WHERE 
    u.Reputation > 100 -- Only include users with a certain reputation
ORDER BY 
    ur.ReputationRank, u.DisplayName;
