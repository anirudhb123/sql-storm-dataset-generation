
WITH PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RevisionOrder
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
         FROM Posts p
         JOIN (SELECT @rownum := @rownum + 1 AS n FROM 
               (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t
               CROSS JOIN (SELECT @rownum := 0) r) n
         WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1  
),
AggregatedVotes AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(ph.Comment SEPARATOR ' | ') AS EditComments,
        MAX(ph.CreationDate) AS LastEditDate,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.Body,
    pi.CreationDate,
    pi.ViewCount,
    pi.Score,
    pi.OwnerDisplayName,
    ag.UpVotes,
    ag.DownVotes,
    phd.EditComments,
    phd.LastEditDate,
    phd.FirstEditDate,
    phd.EditCount
FROM 
    PostInfo pi
LEFT JOIN 
    AggregatedVotes ag ON pi.PostId = ag.PostId
LEFT JOIN 
    PostHistoryDetails phd ON pi.PostId = phd.PostId
WHERE 
    pi.RevisionOrder = 1  
ORDER BY 
    pi.CreationDate DESC
LIMIT 100;
