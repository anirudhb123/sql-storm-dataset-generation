
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @row_number := IF(@prev_user_id = u.Id, @row_number + 1, 1) AS UserRank,
        @prev_user_id := u.Id
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON u.Id = v.UserId,
        (SELECT @row_number := 0, @prev_user_id := NULL) AS vars
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LatestChangeDate,
        GROUP_CONCAT(DISTINCT pht.Name ORDER BY pht.Name SEPARATOR ', ') AS RecentEdits
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        ph.PostId
),
PopularTags AS (
    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        @tag_row_number := @tag_row_number + 1 AS TagRank
    FROM 
        Tags t,
        (SELECT @tag_row_number := 0) AS tag_vars
    WHERE 
        t.Count > 0
    ORDER BY 
        t.Count DESC
)
SELECT 
    ua.DisplayName,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.UpVotes,
    ua.DownVotes,
    rph.LatestChangeDate,
    rph.RecentEdits,
    pt.TagName,
    pt.Count AS TagUsageCount
FROM 
    UserActivity ua
LEFT JOIN 
    RecentPostHistory rph ON ua.UserId = rph.PostId
LEFT JOIN 
    PopularTags pt ON ua.UserRank = pt.TagRank
WHERE 
    ua.UserRank <= 10
ORDER BY 
    ua.UpVotes DESC, ua.QuestionCount DESC;
