
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    CROSS APPLY (SELECT value AS TagName FROM STRING_SPLIT(p.Tags, '>')) t
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        ur.DisplayName AS Author,
        ur.Reputation,
        rp.VoteCount,
        rp.CommentCount,
        rp.Tags
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
),
TopQuestions AS (
    SELECT 
        ps.*,
        ROW_NUMBER() OVER (ORDER BY ps.VoteCount DESC) AS Rank
    FROM 
        PostStats ps
)

SELECT 
    tq.Title,
    tq.Author,
    tq.Reputation,
    tq.VoteCount,
    tq.CommentCount,
    tq.Tags
FROM 
    TopQuestions tq
WHERE 
    tq.Rank <= 10  
ORDER BY 
    tq.VoteCount DESC;
