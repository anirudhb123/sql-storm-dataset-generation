WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
), TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5 -- Only users with more than 5 questions
), TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        RANK() OVER (ORDER BY SUM(v.VoteTypeId = 2) DESC) AS UpvoteRank, -- Counting upvotes as vote type 2
        COUNT(c.Id) AS CommentCount,
        MAX(b.Name) AS BadgeName
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    tp.Title,
    tp.UpvoteRank,
    tp.CommentCount,
    COALESCE((
        SELECT STRING_AGG(DISTINCT b.Name, ', ') 
        FROM Badges b 
        WHERE b.UserId = u.Id
    ), 'No Badges') AS Badges,
    rp.ViewCount,
    rp.Rank
FROM 
    TopUsers u
JOIN 
    TopPosts tp ON tp.Id IN (SELECT PostId FROM RankedPosts WHERE Rank = 1)
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.PostId
ORDER BY 
    u.Reputation DESC, 
    tp.UpvoteRank;
