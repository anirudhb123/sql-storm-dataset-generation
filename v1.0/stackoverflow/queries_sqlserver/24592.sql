
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= DATEADD(year, -1, CAST('2024-10-01' AS date))
    GROUP BY
        p.Id, p.Title, u.DisplayName
),
PostHistorySummary AS (
    SELECT
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(ph.UserDisplayName, ', ' ORDER BY ph.CreationDate DESC) AS Editors
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (4, 5) 
    GROUP BY
        ph.PostId
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        phs.LastEditDate,
        phs.Editors
    FROM
        RankedPosts rp
    JOIN
        PostHistorySummary phs ON rp.PostId = phs.PostId
    WHERE
        rp.rn = 1
        AND rp.CommentCount > 0
        AND (rp.UpVoteCount - rp.DownVoteCount) > 10
)
SELECT TOP 10
    tp.*,
    COALESCE(NULLIF(tp.Editors, ''), 'No edits made') AS EditorInfo,
    CASE
        WHEN tp.UpVoteCount > tp.DownVoteCount THEN 'Positive'
        WHEN tp.UpVoteCount < tp.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    'This post has ' + CAST(tp.CommentCount AS varchar(10)) + ' comments and a score of ' + CAST((tp.UpVoteCount - tp.DownVoteCount) AS varchar(10)) + '.' AS CommentSummary
FROM
    TopPosts tp
ORDER BY
    tp.UpVoteCount DESC, tp.CommentCount DESC;
