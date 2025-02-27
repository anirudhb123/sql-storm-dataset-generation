
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.OwnerUserId
),
RecentPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerDisplayName,
        AnswerCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        RN = 1  
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    COALESCE((SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
               FROM Posts AS p2 
               CROSS APPLY (
                   SELECT VALUE AS TagName 
                   FROM STRING_SPLIT(p2.Tags, ',')
               ) AS t
               WHERE p2.Id = rp.PostId 
               AND t.TagName IS NOT NULL), 
               'No Tags') AS Tags,
    COALESCE((SELECT COUNT(*) 
               FROM Comments c 
               WHERE c.PostId = rp.PostId), 
               0) AS CommentCount
FROM 
    RecentPosts rp
ORDER BY 
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
