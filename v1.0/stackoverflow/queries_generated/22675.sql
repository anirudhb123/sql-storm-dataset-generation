WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        p.Tags,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, CURRENT_TIMESTAMP)
),

JoinedData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        rp.PostId,
        rp.Score,
        rp.RankScore,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(b.Name, 'No Badge') AS Badge,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        LATERAL (SELECT DISTINCT TAGNAME FROM Tags t WHERE t.Id = ANY(string_to_array(rp.Tags, ','))) AS t ON TRUE
    GROUP BY 
        u.Id, rp.PostId, rp.Score, rp.RankScore, rp.UpVotes, rp.DownVotes, b.Name
),

ClosedOrDeleted AS (
    SELECT 
        p.Id,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 12) THEN 'Closed/Deleted' 
            ELSE NULL 
        END AS Status
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        ph.PostHistoryTypeId IS NOT NULL
),

FinalResults AS (
    SELECT 
        jd.*,
        cod.Status
    FROM 
        JoinedData jd
    LEFT JOIN 
        ClosedOrDeleted cod ON jd.PostId = cod.Id
)

SELECT 
    *,
    CASE 
        WHEN UpVotes - DownVotes < 0 THEN 'Overall negative score'
        WHEN UpVotes - DownVotes = 0 THEN 'Neutral score'
        ELSE 'Overall positive score'
    END AS ScoreCategory,
    CURRENT_TIMESTAMP AS QueryTimestamp
FROM 
    FinalResults
WHERE 
    RankScore <= 10
ORDER BY 
    Score DESC, PostId DESC
OPTION (RECOMPILE);
