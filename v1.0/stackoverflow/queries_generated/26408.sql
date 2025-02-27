WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'), 1) AS TagCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions
        AND p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year') -- Posts from the last year
    GROUP BY 
        p.Id, p.Title, p.Body
),

UserDetails AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9)  -- Bounty Start and Close votes
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.PostID,
    rp.Title,
    rp.Body,
    rp.TagCount,
    rp.CommentCount,
    rp.AnswerCount,
    ud.DisplayName AS OwnerDisplayName,
    ud.TotalBadges,
    ud.TotalBounties
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.PostID = u.Id
JOIN 
    UserDetails ud ON u.Id = ud.UserID
WHERE
    rp.PostRank = 1  -- Only the most recent post per user
ORDER BY 
    rp.CommentCount DESC, 
    rp.AnswerCount DESC
LIMIT 100;  -- Limit the output to the top 100 results
