
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Tags,
        LEN(REPLACE(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><', ','), ',', '')) + 1 AS TagCount,
        SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            ELSE 0 
        END) AS Upvotes,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 1 
            ELSE 0 
        END) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId IN (1, 2)
    GROUP BY 
        p.Id, p.Title, p.Body, u.DisplayName, p.CreationDate, p.Tags
),

TopPosts AS (
    SELECT 
        rp.*, 
        RANK() OVER (ORDER BY rp.Upvotes DESC) AS VoteRank,
        RANK() OVER (ORDER BY rp.CommentCount DESC) AS CommentRank,
        RANK() OVER (ORDER BY rp.CloseCount DESC) AS CloseRank
    FROM 
        RankedPosts rp
)

SELECT 
    PostId,
    Title,
    Author,
    CreationDate,
    TagCount,
    Upvotes,
    CommentCount,
    CloseCount,
    (SELECT MIN(OverallRank) 
     FROM (VALUES (VoteRank), (CommentRank), (CloseRank)) AS R(OverallRank)) AS OverallRank
FROM 
    TopPosts
WHERE 
    TagCount > 0  
ORDER BY 
    OverallRank ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
