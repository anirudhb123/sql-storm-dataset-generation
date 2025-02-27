WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Body, 
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '>')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Considering bounties
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.Body,
    rp.CommentCount,
    rp.VoteCount,
    rp.Tags,
    pu.DisplayName AS TopAuthor,
    pu.PostCount,
    pu.TotalBounties
FROM 
    RankedPosts rp
JOIN 
    PopularUsers pu ON rp.OwnerUserId = pu.UserId
WHERE 
    rp.OwnerPostRank <= 5 -- Selecting top 5 posts per user
ORDER BY 
    rp.VoteCount DESC, 
    rp.CommentCount DESC
LIMIT 50;
