
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        u.Reputation,
        p.Score,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
          UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE n <= (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1)) t ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, u.Reputation, p.Score
),

RecentPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY CreationDate DESC) AS RecentRank
    FROM 
        RankedPosts
),

PostActivity AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.Reputation,
        rp.Score,
        rp.Tags,
        rp.CommentCount,
        rp.AnswerCount,
        ph.Comment AS LastEditComment,
        ph.CreationDate AS LastEditDate,
        ph.UserDisplayName AS LastEditor
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId = 24 
    WHERE 
        rp.RecentRank <= 10  
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.Author,
    pa.Reputation,
    pa.Score,
    pa.Tags,
    pa.CommentCount,
    pa.AnswerCount,
    pa.LastEditComment,
    pa.LastEditDate,
    pa.LastEditor
FROM 
    PostActivity pa
ORDER BY 
    pa.CreationDate DESC;
