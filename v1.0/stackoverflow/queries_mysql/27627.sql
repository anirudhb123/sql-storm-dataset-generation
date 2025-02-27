
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsArray,
        ROW_NUMBER() OVER (PARTITION BY YEAR(p.CreationDate) ORDER BY COUNT(v.Id) DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        (SELECT TRIM(BOTH '>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<', n.n), '>', -1)) AS tag
         FROM (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
               SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
         WHERE n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '>', '')) + 1) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
), ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ph.UserDisplayName AS CloserDisplayName
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        pht.Name = 'Post Closed'
)

SELECT 
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.VoteCount,
    rp.TagsArray,
    clp.CloseReason,
    clp.CloserDisplayName,
    rp.PostRank
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts clp ON rp.PostId = clp.PostId
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    rp.CreationDate DESC;
