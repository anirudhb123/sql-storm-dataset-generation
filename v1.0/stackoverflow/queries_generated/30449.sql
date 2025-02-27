WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
MostActiveUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS UserRank
    FROM
        Users u
    JOIN
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY
        u.Id, u.DisplayName
    HAVING
        COUNT(p.Id) > 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON c.Id = CAST(ph.Comment AS int)
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    mau.UserId,
    mau.DisplayName AS ActiveUserDisplayName,
    mau.PostCount,
    mau.TotalScore,
    cp.CloseReasons,
    cp.LastClosedDate
FROM
    RankedPosts rp
JOIN
    MostActiveUsers mau ON mau.UserId = rp.OwnerUserId
LEFT JOIN
    ClosedPosts cp ON cp.PostId = rp.PostId
WHERE
    rp.UserPostRank <= 5
ORDER BY
    rp.CreationDate DESC, rp.Score DESC
FETCH FIRST 100 ROWS ONLY;
