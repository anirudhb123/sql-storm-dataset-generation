WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(vote.UpVotes, 0) AS UpVotes,
        COALESCE(vote.DownVotes, 0) AS DownVotes,
        COALESCE(badge.BadgeCount, 0) AS BadgeCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM
        Posts p
    LEFT JOIN 
        (SELECT
            PostId,
            SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes v
         JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
         GROUP BY PostId) AS vote ON p.Id = vote.PostId
    LEFT JOIN 
        (SELECT
            UserId,
            COUNT(*) AS BadgeCount
         FROM Badges
         GROUP BY UserId) AS badge ON badge.UserId = p.OwnerUserId
    LEFT JOIN 
        (SELECT
            PostId,
            STRING_AGG(TagName, ', ') AS TagName
         FROM PostTags pt
         JOIN Tags t ON pt.TagId = t.Id
         GROUP BY PostId) AS t ON p.Id = t.PostId
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount
),

RankedPosts AS (
    SELECT
        ps.*,
        ROW_NUMBER() OVER (ORDER BY ps.ViewCount DESC, ps.AnswerCount DESC) AS Rank
    FROM PostStats ps
)

SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.BadgeCount,
    rp.Tags,
    rp.Rank
FROM RankedPosts rp
WHERE rp.Rank <= 10
ORDER BY rp.Rank;
