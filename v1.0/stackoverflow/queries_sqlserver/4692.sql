
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(year, 1, 0)
        AND p.ViewCount > 0
), UserVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
), PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tag_name ON 1=1
    JOIN 
        Tags t ON t.TagName = tag_name.value
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    COALESCE(uv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(uv.DownVotes, 0) AS TotalDownVotes,
    rp.ViewCount,
    pt.Tags,
    CASE 
        WHEN rp.RN = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRank,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM PostHistory ph 
            WHERE ph.PostId = rp.PostId 
            AND ph.PostHistoryTypeId = 10
        ) THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVotes uv ON rp.PostId = uv.PostId
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    rp.RN <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
