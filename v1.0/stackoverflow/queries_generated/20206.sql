WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(CAST(SUBSTRING(p.Tags, 2, CHAR_LENGTH(p.Tags) - 2) AS VARCHAR(200)), 'No Tags') AS CleanTags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        v.UserId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        STRING_AGG(DISTINCT ph.Comment, ', ') AS Comments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
HighlightedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE(uh.UpVoteCount, 0) AS UserUpVoteCount,
        COALESCE(uh.DownVoteCount, 0) AS UserDownVoteCount,
        phs.ChangeCount AS ModificationCount,
        phs.Comments AS HistoryComments
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserVoteCounts uh ON uh.UserId = (SELECT MIN(UserId) FROM Users) -- Obscure selection logic
    LEFT JOIN 
        PostHistoryStats phs ON phs.PostId = rp.PostId
    WHERE 
        rp.Rank <= 5  -- Top 5 posts in each category
)
SELECT 
    hp.PostId,
    hp.Title,
    hp.CreationDate,
    hp.ViewCount,
    hp.Score,
    hp.UserUpVoteCount,
    hp.UserDownVoteCount,
    hp.ModificationCount,
    hp.HistoryComments,
    CASE 
        WHEN hp.ViewCount IS NULL THEN 'Not Visited'
        WHEN hp.ViewCount > 1000 THEN 'Popular'
        ELSE 'Moderate'
    END AS PopularityStatus
FROM 
    HighlightedPosts hp
ORDER BY 
    hp.Score DESC, hp.CreationDate ASC;
