
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER(PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        u.Reputation, 
        SUM(v.BountyAmount) AS TotalBountyReceived,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopTags AS (
    SELECT 
        value AS TagName, 
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, '>') 
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        value
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)

SELECT 
    us.DisplayName AS UserDisplayName,
    us.Reputation,
    rp.Title AS PostTitle,
    rp.Score,
    rp.ViewCount,
    us.TotalBountyReceived,
    us.TotalUpVotes,
    us.TotalDownVotes,
    tt.TagName,
    rp.CommentCount
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.OwnerUserId = us.UserId
JOIN 
    TopTags tt ON tt.TagName IN (SELECT value FROM STRING_SPLIT(rp.Title, ' '))  
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, us.Reputation ASC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
