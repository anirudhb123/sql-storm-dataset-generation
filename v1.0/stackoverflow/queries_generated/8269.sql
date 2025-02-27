WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        AVG(vote.Score) AS AverageVoteScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN
        Votes vote ON p.Id = vote.PostId
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT
        rp.*,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS GlobalRank
    FROM
        RankedPosts rp
    WHERE
        rp.AnswerCount > 0
)
SELECT
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.AverageVoteScore,
    tp.GlobalRank
FROM
    TopPosts tp
WHERE
    tp.GlobalRank <= 100
ORDER BY
    tp.GlobalRank;
