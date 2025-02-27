WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes
         GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
), RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.Score DESC, ps.CloseCount, ps.ReopenCount) AS Rank
    FROM 
        PostStats ps
), RecentTopPosts AS (
    SELECT 
        RP.*,
        ROW_NUMBER() OVER (PARTITION BY YEAR(RP.CreationDate) ORDER BY RP.Rank) AS YearlyRank
    FROM 
        RankedPosts RP
    WHERE 
        Rank <= 10
)
SELECT 
    RTP.PostId,
    RTP.Title,
    RTP.Score,
    RTP.OwnerDisplayName,
    RTP.UpVotes,
    RTP.DownVotes,
    RTP.CloseCount,
    RTP.ReopenCount,
    RTP.Rank,
    RTP.YearlyRank
FROM 
    RecentTopPosts RTP
WHERE 
    RTP.YearlyRank = 1
ORDER BY 
    RTP.Rank, RTP.CloseCount DESC;
