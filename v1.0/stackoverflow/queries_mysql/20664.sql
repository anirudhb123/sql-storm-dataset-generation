
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Deleted User') AS UserDisplayName
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
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
    COALESCE(ph.Comment, 'No Close Reason') AS CloseReason,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
FROM
    PostDetails pd
LEFT JOIN
    PostHistory ph ON ph.PostId = pd.PostId AND ph.PostHistoryTypeId = 10 
LEFT JOIN
    Posts p ON pd.PostId = p.Id
LEFT JOIN
    (SELECT DISTINCT TagName FROM (
        SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
        FROM
            (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) AS numbers
        JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
    ) AS TagList) AS t ON TRUE 
GROUP BY
    pd.PostId, pd.Title, pd.Score, pd.AnswerCount, pd.CreationDate,
    pd.UserDisplayName, pd.UpVotes, pd.DownVotes, pd.TotalVotes, pd.BadgeStatus, ph.Comment
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC
LIMIT 20;
