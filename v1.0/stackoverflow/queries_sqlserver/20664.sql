
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        ISNULL(u.DisplayName, 'Deleted User') AS UserDisplayName
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        Score,
        AnswerCount,
        CreationDate,
        UserDisplayName
    FROM
        RankedPosts
    WHERE
        Rank <= 5
),
VoteSummary AS (
    SELECT
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM
        Votes
    GROUP BY
        PostId
),
PostDetails AS (
    SELECT
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.AnswerCount,
        tp.CreationDate,
        tp.UserDisplayName,
        vs.UpVotes,
        vs.DownVotes,
        vs.TotalVotes,
        CASE
            WHEN bp.Id IS NOT NULL THEN 'Has Badge'
            ELSE 'No Badge'
        END AS BadgeStatus
    FROM
        TopPosts tp
    LEFT JOIN
        Badges bp ON bp.UserId IN (
            SELECT UserId FROM Users WHERE DisplayName = tp.UserDisplayName
        )
    LEFT JOIN
        VoteSummary vs ON tp.PostId = vs.PostId
)
SELECT
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.AnswerCount,
    pd.CreationDate,
    pd.UserDisplayName,
    pd.UpVotes,
    pd.DownVotes,
    pd.TotalVotes,
    pd.BadgeStatus,
    ISNULL(ph.Comment, 'No Close Reason') AS CloseReason,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM
    PostDetails pd
LEFT JOIN
    PostHistory ph ON ph.PostId = pd.PostId AND ph.PostHistoryTypeId = 10 
LEFT JOIN
    Posts p ON pd.PostId = p.Id
LEFT JOIN
    STRING_SPLIT(p.Tags, ', ') AS t(TagName) ON 1=1 
GROUP BY
    pd.PostId, pd.Title, pd.Score, pd.AnswerCount, pd.CreationDate,
    pd.UserDisplayName, pd.UpVotes, pd.DownVotes, pd.TotalVotes, pd.BadgeStatus, ph.Comment
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
