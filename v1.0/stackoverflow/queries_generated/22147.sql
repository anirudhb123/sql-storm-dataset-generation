WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.CommentCount > 0 THEN 'Has Comments'
            ELSE 'No Comments'
        END AS CommentStatus,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY rp.PostId), 0) AS UpVotesCount,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY rp.PostId), 0) AS DownVotesCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    WHERE 
        rp.PostRank <= 5
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastActivityDate,
        MAX(ph.UserId) AS LastEditorId
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10, 11)
    GROUP BY 
        p.Id
),
FinalResults AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.ViewCount,
        fp.CommentStatus,
        fp.UpVotesCount,
        fp.DownVotesCount,
        ra.LastActivityDate,
        CASE 
            WHEN ra.LastEditorId IS NULL THEN 'No Edits Found'
            ELSE (SELECT DisplayName FROM Users WHERE Id = ra.LastEditorId)
        END AS LastEditorName
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        RecentActivity ra ON fp.PostId = ra.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.CommentStatus,
    fr.UpVotesCount - fr.DownVotesCount AS NetVoteScore,
    fr.LastActivityDate,
    COALESCE(fr.LastEditorName, 'System') AS LastEditorName
FROM 
    FinalResults fr
WHERE 
    fr.LastActivityDate >= NOW() - INTERVAL '30 days' AND
    fr.Score > 0
ORDER BY 
    fr.NetVoteScore DESC, fr.ViewCount DESC;
