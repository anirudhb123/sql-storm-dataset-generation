
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankDate
    FROM 
        Posts p
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        CASE 
            WHEN rp.RankScore <= 5 THEN 'Top 5'
            WHEN rp.RankDate <= 10 THEN 'Recent 10'
            END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 5 OR rp.RankDate <= 10
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.CreationDate,
    fp.ViewCount,
    COALESCE(pvs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvs.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN fp.Score > 10 THEN 'High Score Group'
        ELSE 'Low Score Group'
    END AS ScoreGroup,
    COALESCE(t.TagName, 'No Tags') AS TagName,
    CASE 
        WHEN fp.PostCategory IS NOT NULL THEN 'Featured Post'
        ELSE 'Regular Post'
    END AS PostType
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostVoteSummary pvs ON fp.PostId = pvs.PostId
LEFT JOIN 
    Posts AS p ON fp.PostId = p.Id
LEFT JOIN 
    (SELECT 
         p.Id,
         SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
     FROM 
         Posts p
     INNER JOIN 
         ( SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
           UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
           UNION ALL SELECT 10 ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) AS t ON fp.PostId = t.Id
WHERE 
    p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 30 DAY)
    AND (p.OwnerUserId IS NOT NULL OR fp.PostCategory IS NOT NULL)
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC;
