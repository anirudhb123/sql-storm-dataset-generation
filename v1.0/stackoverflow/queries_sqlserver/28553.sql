
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= CAST(DATEADD(DAY, -30, '2024-10-01') AS DATE) 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.BadgeCount,
        rp.UpVoteCount,
        u.DisplayName AS OwnerDisplayName
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        rp.UserPostRank <= 5
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= CAST(DATEADD(DAY, -90, '2024-10-01') AS DATE)
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        PostsCreated DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    t.Title,
    t.CommentCount,
    t.BadgeCount,
    t.UpVoteCount,
    t.OwnerDisplayName,
    mau.DisplayName AS MostActiveUser,
    mau.PostsCreated
FROM 
    TopPosts t
JOIN 
    MostActiveUsers mau ON t.OwnerDisplayName = mau.DisplayName;
