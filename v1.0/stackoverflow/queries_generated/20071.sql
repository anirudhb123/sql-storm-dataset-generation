WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(p.Id) DESC) AS Rank
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY
        u.Id
),

PostHistoryDetails AS (
    SELECT
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        p.Title,
        p.Body,
        ph.Comment,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevisionRank
    FROM
        PostHistory ph
    JOIN
        Posts p ON ph.PostId = p.Id
    WHERE
        p.CreationDate <= NOW() -- Considering only the posts created till date
),

RecentPostChanges AS (
    SELECT
        p.Id AS PostId,
        p.CreationDate AS PostCreationDate,
        COUNT(ph.Id) AS ModificationCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS ChangeComments
    FROM
        Posts p
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId
    WHERE
        ph.CreationDate >= (NOW() - INTERVAL '1 month')
    GROUP BY
        p.Id, p.CreationDate
)

SELECT
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.AnswerCount,
    ups.QuestionCount,
    ups.TotalBounty,
    p.PostId,
    CASE 
        WHEN p.PostCreationDate >= (NOW() - INTERVAL '1 month') THEN 'Recent'
        ELSE 'Older'
    END AS PostAge,
    p.ModificationCount,
    p.LastEditDate,
    p.ChangeComments,
    CASE 
        WHEN p.ModificationCount > 5 THEN 'Highly Modified'
        ELSE 'Less Modified'
    END AS ModificationType
FROM
    UserPostStats ups
LEFT JOIN
    RecentPostChanges p ON ups.UserId = p.UserId
WHERE
    ups.Rank = 1 -- Getting the top user only
ORDER BY
    ups.TotalBounty DESC, 
    p.ModificationCount DESC NULLS LAST;
