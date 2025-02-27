
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        LEN(REPLACE(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><', ','), '<', '')) - LEN(REPLACE(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><', ','), '<', '')) + 1 AS TagCount,
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
        p.PostTypeId = 1  
        AND p.CreationDate >= DATEADD(year, -1, CAST('2024-10-01' AS date))
    GROUP BY 
        p.Id, p.Title, p.Body, p.OwnerUserId, p.CreationDate
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
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9)  
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
    rp.PostRank = 1  
ORDER BY 
    rp.CommentCount DESC, 
    rp.AnswerCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
