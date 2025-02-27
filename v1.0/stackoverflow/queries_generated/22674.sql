WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentTotal,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL string_to_array(p.Tags, ',') AS a(tag) ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(BOTH ' ' FROM a.tag)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerUserId,
        rp.RankScore,
        rp.CommentTotal,
        rp.TagsList,
        U.DisplayName AS OwnerName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        SUM(CASE WHEN hp.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        MAX(hp.CreationDate) AS LastHistoryChange
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users U ON rp.OwnerUserId = U.Id
    LEFT JOIN 
        Badges b ON U.Id = b.UserId
    LEFT JOIN 
        PostHistory hp ON rp.PostId = hp.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.OwnerUserId, rp.RankScore, rp.TagsList, U.DisplayName
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.OwnerName,
    pd.RankScore,
    pd.CommentTotal,
    pd.TagsList,
    pd.TotalBadges,
    pd.CloseCount,
    pd.LastHistoryChange,
    CASE 
        WHEN pd.CloseCount > 0 THEN 'Closed'
        WHEN pd.CommentTotal = 0 THEN 'No Comments'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN pd.LastHistoryChange IS NULL THEN 'Never Modified'
        WHEN pd.LastHistoryChange < NOW() - INTERVAL '1 year' THEN 'Inactive for over a year'
        ELSE 'Recently Modified'
    END AS ModificationStatus,
    (SELECT AVG(UpVotes) FROM Users WHERE UpVotes IS NOT NULL) AS AvgUserUpVotes,
    (SELECT COUNT(*) FROM Votes WHERE VoteTypeId = 3 AND PostId = pd.PostId) AS DownVoteCount,
    (SELECT COUNT(*) FROM Votes WHERE VoteTypeId = 2 AND PostId = pd.PostId) AS UpVoteCount
FROM 
    PostDetails pd
WHERE 
    pd.RankScore <= 5
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- Note: The query above aggregates post data, along with user and history information, filters by rank, and orders the final results for performance benchmarking.
