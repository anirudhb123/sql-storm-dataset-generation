WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000 -- Filtered for highly reputed users
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(ch.CommentCount, 0) AS RecentCommentCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        WHERE 
            CreationDate >= NOW() - INTERVAL '30 days' -- Last 30 days
        GROUP BY 
            PostId
    ) ch ON p.Id = ch.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Last year
)
SELECT 
    tu.DisplayName AS UserName,
    tu.Reputation,
    p.Title AS PostTitle,
    p.CreationDate AS PostDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    COALESCE(Total.CommentCount, 0) AS TotalComments,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    (CASE 
         WHEN p.Score > 50 THEN 'Hot'
         WHEN p.Score > 20 THEN 'Trending'
         ELSE 'Regular'
     END) AS PostStatus,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     WHERE t.WikiPostId = p.Id) AS AssociatedTags
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.PostId = p.Id
JOIN 
    TopUsers tu ON p.OwnerUserId = tu.UserId
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
) Total ON Total.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9) -- Bounty votes
WHERE 
    rp.UserPostRank <= 5 -- Top 5 posts from users
GROUP BY 
    tu.DisplayName, tu.Reputation, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, Total.CommentCount
ORDER BY 
    tu.Reputation DESC, p.CreationDate DESC;
