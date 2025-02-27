WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM Posts p 
    WHERE p.CreationDate >= DATEADD(year, -2, GETDATE()) -- posts from the last 2 years
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id 
    GROUP BY v.PostId
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON TRY_CAST(ph.Comment AS INT) = cr.Id
    WHERE ph.PostHistoryTypeId = 10 -- Close event
    GROUP BY ph.PostId
),
CombinedResults AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        rb.TotalBadges,
        rb.GoldBadges,
        rb.SilverBadges,
        rb.BronzeBadges,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        COALESCE(pvc.VoteCount, 0) AS VoteCount,
        COALESCE(pvc.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(pvc.DownVoteCount, 0) AS DownVoteCount,
        COALESCE(pcr.CloseReasons, 'No close reasons') AS CloseReasons
    FROM RankedPosts rp
    JOIN Users up ON rp.OwnerUserId = up.Id
    LEFT JOIN UserBadges rb ON up.Id = rb.UserId
    LEFT JOIN PostVoteCounts pvc ON rp.PostId = pvc.PostId
    LEFT JOIN PostCloseReasons pcr ON rp.PostId = pcr.PostId
    WHERE rp.PostRank = 1 -- Only top-ranked posts per user
)
SELECT 
    UserId, 
    DisplayName,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostId, 
    Title, 
    CreationDate, 
    Score, 
    ViewCount,
    AnswerCount,
    CommentCount,
    VoteCount,
    UpVoteCount,
    DownVoteCount,
    CloseReasons
FROM CombinedResults
ORDER BY Score DESC, CreationDate DESC
FETCH FIRST 10 ROWS ONLY; -- Fetch the top 10 results
