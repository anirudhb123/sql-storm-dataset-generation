
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
    FROM 
        Posts p
    INNER JOIN (
        SELECT 
            1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
            UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 
            UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 
            UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1  
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEdit
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId
),
PostsSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        pt.TagName,
        pv.UpVotes,
        pv.DownVotes,
        re.EditCount,
        re.LastEdit,
        rp.Rank,
        rp.TotalPosts
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostTags pt ON rp.PostId = pt.PostId
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
    LEFT JOIN 
        RecentEdits re ON rp.PostId = re.PostId
    WHERE 
        rp.Rank <= 5  
)
SELECT DISTINCT
    ps.PostId,
    ps.Title,
    ps.Author,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.TagName,
    COALESCE(ps.UpVotes, 0) AS UpVotes,
    COALESCE(ps.DownVotes, 0) AS DownVotes,
    COALESCE(ps.EditCount, 0) AS EditCount,
    ps.LastEdit,
    ps.Rank,
    ps.TotalPosts
FROM 
    PostsSummary ps
ORDER BY 
    ps.CreationDate DESC, ps.Score DESC;
