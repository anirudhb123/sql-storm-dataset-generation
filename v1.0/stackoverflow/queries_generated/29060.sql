WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts from the last year
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Tags
    FROM
        RankedPosts rp
    WHERE
        rp.Rank <= 5  -- Top 5 posts by type
),
Contributors AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts from the last year
    GROUP BY
        u.Id, u.DisplayName
),
TopContributors AS (
    SELECT
        c.UserId,
        c.DisplayName,
        c.PostCount,
        c.UpVoteCount,
        c.DownVoteCount,
        RANK() OVER (ORDER BY c.PostCount DESC) AS ContributorRank
    FROM
        Contributors c
)
SELECT
    tp.Title AS PostTitle,
    tp.Body AS PostBody,
    tp.CreationDate AS PostCreatedOn,
    tp.ViewCount AS PostViewCount,
    tp.Score AS PostScore,
    tc.DisplayName AS ContributorName,
    tc.PostCount AS ContributorPostCount,
    tc.UpVoteCount AS ContributorUpVotes,
    tc.DownVoteCount AS ContributorDownVotes
FROM
    TopPosts tp
JOIN
    TopContributors tc ON tp.PostId = (SELECT TOP 1 p.Id FROM Posts p WHERE p.OwnerUserId = tc.UserId ORDER BY p.CreationDate DESC)
ORDER BY
    tp.CreationDate DESC, tc.PostCount DESC;
