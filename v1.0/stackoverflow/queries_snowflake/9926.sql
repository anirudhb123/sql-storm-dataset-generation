
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
), 
PopularTags AS (
    SELECT 
        TRIM(value) AS Tag,
        COUNT(*) AS UsageCount
    FROM 
        Posts,
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTRING(Tags, 2, LENGTH(Tags)-2), '> <')) )
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10
), 
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        pht.Name AS HistoryType,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= CURRENT_TIMESTAMP() - INTERVAL '1 YEAR'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.AnswerCount,
    pt.Tag AS PopularTag,
    (SELECT COUNT(*) FROM PostHistoryDetails phd WHERE phd.PostId = rp.PostId) AS RecentHistoryCount,
    (SELECT LISTAGG(DISTINCT phd.UserDisplayName, ', ') WITHIN GROUP (ORDER BY phd.UserDisplayName) FROM PostHistoryDetails phd WHERE phd.PostId = rp.PostId) AS Editors
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.UsageCount > 5  
WHERE 
    rp.PostRank = 1  
ORDER BY 
    rp.Score DESC
LIMIT 20;
