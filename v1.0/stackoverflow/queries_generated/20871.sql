WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId IN (4, 10) THEN 1 ELSE 0 END) AS SpamVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty,
        JSON_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Bounty start and close
    LEFT JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><') AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
CustomRanking AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        Upvotes,
        Downvotes,
        SpamVotes,
        UserRank,
        RANK() OVER (ORDER BY PostCount DESC, Upvotes DESC) AS RankByPostUpvotes
    FROM 
        UserActivity
),
FilteredPosts AS (
    SELECT 
        pd.*, 
        u.DisplayName AS OwnerDisplayName
    FROM 
        PostDetails pd
    JOIN 
        Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = pd.PostId)
    WHERE 
        CommentCount > 5 AND AverageBounty >= 10
)
SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.Score,
    f.OwnerDisplayName,
    f.CommentCount,
    f.Tags,
    CASE 
        WHEN f.Score > 10 THEN 'Hot'
        WHEN f.Score BETWEEN 5 AND 10 THEN 'Trending'
        ELSE 'Needs Attention'
    END AS Popularity
FROM 
    FilteredPosts f
LEFT JOIN 
    CustomRanking cr ON cr.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = f.PostId)
WHERE 
    cr.UserRank IS NOT NULL
ORDER BY 
    f.CommentCount DESC, f.Score DESC;
